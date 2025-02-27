WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), RecentUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Location,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.CreationDate DESC) AS recent_user_rank
    FROM 
        Users u
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '6 months'
), PostInteractions AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        ru.Id AS UserId,
        ru.DisplayName AS UserName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus,
        NULLIF(rp.UpVotes - rp.DownVotes, 0) AS VoteDifference
    FROM 
        RankedPosts rp
    JOIN 
        RecentUsers ru ON rp.OwnerUserId = ru.Id
), FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN VoteDifference IS NOT NULL AND VoteDifference > 0 THEN 'Positive'
            WHEN VoteDifference IS NOT NULL AND VoteDifference < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteStatus
    FROM 
        PostInteractions
)
SELECT 
    f.UserId,
    f.UserName,
    f.Title,
    f.CommentStatus,
    f.VoteStatus,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes
FROM 
    FilteredPosts f
WHERE 
    f.recent_user_rank <= 10
ORDER BY 
    f.Title ASC;
