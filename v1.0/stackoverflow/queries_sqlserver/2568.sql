
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        AVG(ISNULL(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        u.Reputation,
        u.BadgeCount,
        u.AvgPostScore,
        ISNULL(v.UpVoteCount, 0) AS UpVoteCount,
        ISNULL(v.DownVoteCount, 0) AS DownVoteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation u ON (u.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId))
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.Reputation,
    p.BadgeCount,
    p.AvgPostScore,
    CASE 
        WHEN p.Score >= 100 THEN 'High'
        WHEN p.Score BETWEEN 50 AND 99 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory,
    ISNULL(CAST(c.Text AS VARCHAR(MAX)), 'No Comments') AS LatestComment
FROM 
    PostStats p
LEFT JOIN 
    (SELECT 
        PostId, Text 
     FROM 
        Comments 
     WHERE 
        CreationDate = (SELECT MAX(CreationDate) FROM Comments c2 WHERE c2.PostId = Comments.PostId)
    ) c ON p.PostId = c.PostId
WHERE 
    p.BadgeCount > 0 OR p.Reputation > 500
ORDER BY 
    p.Score DESC, p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
