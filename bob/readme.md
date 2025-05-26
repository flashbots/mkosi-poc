BOB
===

This module implements three key features for bottom of block backrunning: 

1. **Network namespaces and firewall rules** that enforce a searcher cannot SSH into the container while state diffs are being streamed in, and the only way information can leave is through the block builder’s endpoints.
2. A **log delay** **script that enforces a two-minute (~10 block) delay until the searcher can view their bot’s logs. 
3. **Mode switching** which allows a searcher to toggle between production and maintenance modes, where the SSH connection is cut and restored respectively. 

Together, they provide the “no-frontrunning” guarantee to order flow providers while balancing searcher bot visibility and maintenance.

Docs: https://flashbots.notion.site/Bob-V2-Image-Guide-1506b4a0d87680b2979de36288b48d9a?pvs=4

![image](https://github.com/user-attachments/assets/aaad8a4e-f640-4a94-b16f-657eb3ff6bdb)

Additional functionality
------------------------

This universal, Mkosi-based version implements additional capabilities which allow searchers to persist data across restarts and version upgrades without sacrificing data privacy and integrity.
When the image boots up, it will open an HTTP server at port 8080 and wait for a ed25519 public key to be submitted. For example, run the qemu image then POST the key to the forwarded port like so:

```
ubuntu@ns5018742:~/Angela/bobgela/keys$ curl -X POST -d "AAAAC3NzaC1lZDI1NTE5AAAAIMPdKdQZip5rYQAhuKTbhI09HM9aFSU/erbUWXb4i4nR" http://localhost:8080
```

This step is only necessary if the persistent disk has not been initialized.

Then, using the dropbear port, you can initialize or decrypt an existing disk by running the "initialize" command (rather than toggle, status, etc). This will prompt you for a password via stdin. This step is necessary on each boot. When you initialize as disk, it will store the previously supplied public key in plaintext inside of the LUKS header so it can be retrieved automatically on subsequent boots.

Service Order
-------------

1. Initialize network (**name:** `network-setup.service`)
2. Get searcher key from LUKS partition or wait for key on port 8080 (**name:** `wait-for-key.service`) (**after:** `network-setup.service`)
3. Setup firewall (**name:** `searcher-firewall.service`) (**after:** `network-setup.service`)
4. Start dropbear server for `initialize`, `toggle`, etc. (**name:** `dropbear.service`) (**after:** `wait-for-key.service`, `searcher-firewall.service`)
5. Open a log socket and forward text from it to the delayed log file after 120s (**name:** searcher-log-reader.service) (**after:** `/persistent` is mounted)
6. Write new text in `bob.log` to the log socket (**name:** searcher-log-writer.service) (**after:** searcher-log-reader.service)
7. Lighthouse (**name:** `lighthouse.service`) (**after:** `/persistent` is mounted)
8. Start the podman container (**name:** `searcher-container.service`) (**after:** `dropbear.service`, `lighthouse.service`, `searcher-firewall.service`, `/persistent` is mounted)
9. SSH pubkey server (**name:** `ssh-pubkey-server.service`) (**after:** `searcher-container.service`)
10. CVM reverse proxy for SSH pubkey server (**name:** `cvm-reverse-proxy.service`) (**after:** `ssh-pubkey-server.service`)

Testing
-------

```shell
ssh-keygen -t ed25519
curl -X POST -d "$(cut -d" " -f2 /root/.ssh/id_ed25519.pub)" http://localhost:8080
sleep 1
# start here if recovering existing persistent disk (assumes searcher key is in /root/.ssh)
ssh -4 -i /root/.ssh/id_ed25519 searcher@127.0.0.1 initialize
journalctl -fu searcher-container
ssh -4 -i /root/.ssh/id_ed25519 -p 10022 root@127.0.0.1
ssh -4 -i /root/.ssh/id_ed25519 searcher@127.0.0.1 toggle
```