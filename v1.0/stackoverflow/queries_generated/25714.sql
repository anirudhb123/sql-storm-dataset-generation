WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT * FROM STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.Rank,
        rp.TagList,
        COALESCE(c.CommentCount, 0) AS TotalComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON rp.PostId = c.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.AnswerCount,
    ps.Score,
    ps.Rank,
    ps.TagList,
    ps.TotalComments,
    CASE 
        WHEN ps.Rank <= 10 THEN 'Top Post' 
        ELSE 'Other Post' 
    END AS PostCategory,
    DATE_TRUNC('month', ps.CreationDate) AS PostMonth,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes 
FROM 
    PostStatistics ps
LEFT JOIN 
    Votes v ON ps.PostId = v.PostId 
GROUP BY 
    ps.PostId, ps.Title, ps.OwnerDisplayName, ps.ViewCount, ps.AnswerCount, ps.Score, 
    ps.Rank, ps.TagList, ps.TotalComments, ps.CreationDate
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
