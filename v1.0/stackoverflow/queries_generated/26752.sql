WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
    FROM 
        Posts p
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TagRankings AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION('>' || t.TagName || '<' IN '<' || p.Tags || '>') > 0
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        tr.TagName,
        tr.PostCount,
        tr.TotalViews,
        tr.TotalScore,
        tr.UniqueUsers,
        ROW_NUMBER() OVER (ORDER BY tr.TotalScore DESC) AS TagRank
    FROM 
        TagRankings tr
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerName,
    rp.Rank,
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.TotalScore,
    tt.UniqueUsers
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON POSITION('>' || tt.TagName || '<' IN '<' || rp.Tags || '>') > 0
WHERE 
    rp.Rank <= 5 AND tt.TagRank <= 10
ORDER BY 
    rp.Rank, tt.TotalScore DESC;
