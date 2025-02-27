WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        unnest(string_to_array(rp.Tags, '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(both '<>' from tag)
    WHERE 
        rp.rn = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount
),
AggregateStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        SUM(TotalCommentScore) AS TotalComments
    FROM 
        PostStats
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TagList,
    as.TotalPosts,
    as.AvgScore,
    as.AvgViewCount,
    as.TotalComments
FROM 
    PostStats ps, AggregateStats as
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
