WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TagStats AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '>')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(u.Reputation) AS TotalReputation,
        ROW_NUMBER() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title AS PostTitle,
    rp.CreationDate AS PostDate,
    rp.ViewCount AS PostViews,
    ts.Tag AS RelatedTag,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews,
    ts.AvgViews AS TagAvgViews,
    ur.DisplayName AS AuthorName,
    ur.PostsCreated AS AuthorPosts,
    ur.TotalReputation AS AuthorReputation,
    ur.UserRank AS AuthorRank
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON rp.Tags LIKE '%' || ts.Tag || '%'
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    ts.TotalViews DESC, rp.CreationDate DESC;
