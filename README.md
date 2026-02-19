# Owasp K3s Cluster on iximiuz Labs

This is a playground with a deliberately misconfigured k3s cluster so that users can practice running a scanner, finding issues, and then remediating them. It's not entirely authentic, but is an MVP demo to illustrate what deliberate practice with this particular learning objective could look like.

It uses the kubernetes operator defined in https://github.com/lpmi-13/vulnerable-lab-operator to reconcile the state and reset when each vulnerability is fixed.
