WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVoteCount, 0) AS UpVotes,
        COALESCE(v.DownVoteCount, 0) AS DownVotes,
        COALESCE(ch.CommentCount, 0) AS Comments,
        COALESCE(b.BadgeCount, 0) AS Badges,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) ch ON p.Id = ch.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.UpVotes,
    rp.DownVotes,
    rp.Comments,
    rp.Badges,
    pt.Name AS PostType
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostRank <= 5 AND pt.Id = rp.PostTypeId
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.CreationDate DESC;
