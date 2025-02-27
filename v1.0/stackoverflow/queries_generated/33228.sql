WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) OVER() AS TotalQuestions
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.Score > 5
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(Id) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.ScoreRank,
        mc.CommentCount,
        CAST(DATEDIFF(day, rp.CreationDate, GETDATE()) AS FLOAT) / NULLIF(rp.Score, 0) AS DaysPerScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MostCommentedPosts mc ON rp.PostId = mc.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.OwnerDisplayName,
    pm.ScoreRank,
    COALESCE(pm.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN pm.DaysPerScore IS NULL THEN 'Not Applicable'
        WHEN pm.DaysPerScore < 1 THEN 'High Engagement'
        WHEN pm.DaysPerScore BETWEEN 1 AND 3 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pm.PostId AND v.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT value FROM STRING_SPLIT(SUBSTRING(pm.Title, CHARINDEX('#', pm.Title) + 1, LEN(pm.Title)), ', '))) ) AS RelatedTags
FROM 
    PostMetrics pm
WHERE 
    pm.ScoreRank <= 10
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
