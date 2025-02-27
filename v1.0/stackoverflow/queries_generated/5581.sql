WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, v.UpVotes, v.DownVotes
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.UserPostRank,
        rp.CommentCount,
        rp.BadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 3 AND 
        rp.Score > 10 
)
SELECT 
    u.DisplayName,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.BadgeCount
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC
LIMIT 100;
