WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserRankedPosts AS (
    SELECT 
        rp.*, 
        u.DisplayName AS OwnerDisplayName, 
        u.Reputation,
        RANK() OVER (ORDER BY rp.Score DESC) AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
)
SELECT 
    urp.PostId,
    urp.Title,
    urp.CreationDate,
    urp.Score,
    urp.ViewCount,
    urp.CommentCount,
    urp.UpVoteCount,
    urp.DownVoteCount,
    urp.UserPostRank,
    urp.OverallRank,
    urp.OwnerDisplayName,
    urp.Reputation
FROM 
    UserRankedPosts urp
WHERE 
    urp.UserPostRank <= 5 -- Top 5 posts per user
ORDER BY 
    urp.OverallRank, urp.ViewCount DESC;
