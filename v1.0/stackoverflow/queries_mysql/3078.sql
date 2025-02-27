
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @rn := IF(@prev = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prev := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        (SELECT @rn := 0, @prev := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(rp.UpVotes, 0) AS SafeUpVotes,
        COALESCE(rp.DownVotes, 0) AS SafeDownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        Users u
    JOIN 
        (SELECT @user_rank := 0) AS vars
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.SafeUpVotes,
    fp.SafeDownVotes,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    CASE 
        WHEN fp.SafeUpVotes > fp.SafeDownVotes THEN 'Positively Received' 
        WHEN fp.SafeUpVotes < fp.SafeDownVotes THEN 'Negatively Received' 
        ELSE 'Neutral' 
    END AS ReceptionStatus
FROM 
    FilteredPosts fp
JOIN 
    Posts p ON fp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
ORDER BY 
    fp.CommentCount DESC, fp.CreationDate DESC;
