WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        ARRAY_AGG(CONVERT(VARCHAR, t.TagName)) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT v.Id) AS VotesCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON c.UserId = u.Id AND c.CreationDate > DATEADD(MONTH, -6, GETDATE())
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.CreationDate > DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(ra.CommentsCount, 0) AS RecentComments,
        COALESCE(ra.VotesCount, 0) AS RecentVotes,
        rp.TagsArray,
        CASE 
            WHEN rp.Score >= 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 99 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON ra.UserId = rp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.RecentComments,
    ps.RecentVotes,
    ps.TagsArray,
    ps.ScoreCategory,
    JSON_AGG(DISTINCT u.EmailHash) AS UserEmails
FROM 
    PostStatistics ps
LEFT JOIN 
    Users u ON u.Id = (SELECT ph.UserId
                         FROM PostHistory ph
                         WHERE ph.PostId = ps.PostId AND ph.PostHistoryTypeId = 25
                         ORDER BY ph.CreationDate DESC
                         LIMIT 1)
WHERE 
    ps.ViewCount > 100 
    AND ps.RecentVotes > 0
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, 
    ps.RecentComments, ps.RecentVotes, ps.TagsArray, ps.ScoreCategory
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
