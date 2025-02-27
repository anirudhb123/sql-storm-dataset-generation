WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
), TagStats AS (
    SELECT 
        unnest(string_to_array(TRIM(BOTH '<>' FROM p.Tags), '><')) AS TagName,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AverageViews,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM 
        RankedPosts p
    WHERE 
        p.rn <= 5 -- Take top 5 posts per tag
    GROUP BY 
        TagName
), MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(*) AS PostCount,
        SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
    GROUP BY 
        u.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AverageViews,
    ts.UniqueAuthors,
    mau.DisplayName AS MostActiveUser,
    mau.PostCount AS UserPosts,
    mau.TotalUpVotes
FROM 
    TagStats ts
JOIN 
    MostActiveUsers mau ON ts.UniqueAuthors > 0
ORDER BY 
    ts.PostCount DESC, ts.AverageViews DESC;
