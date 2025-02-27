WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5  -- Top 5 Posts per User
    GROUP BY 
        OwnerDisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = CAST(STRING_AGG(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), ',') AS INT)
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    mau.OwnerDisplayName,
    mau.TotalPosts,
    mau.TotalComments,
    tt.TagName,
    tt.PostCount
FROM 
    MostActiveUsers mau
CROSS JOIN 
    TopTags tt
ORDER BY 
    mau.TotalPosts DESC, mau.TotalComments DESC;
