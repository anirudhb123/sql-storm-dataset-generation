WITH RankedTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING(tag.TagName FROM 1 FOR 35))) AS NormalizedTag,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags tag
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    WHERE 
        tag.TagName IS NOT NULL
    GROUP BY 
        NormalizedTag
),
TopTags AS (
    SELECT 
        NormalizedTag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        RankedTags
    WHERE 
        PostCount > 0
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ARRAY_AGG(b.Name) AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.NormalizedTag) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id, p.Title, p.Score
    HAVING 
        p.Score >= (SELECT AVG(Score) FROM Posts)
)
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    tp.NormalizedTag AS Tag,
    up.Badges AS UserBadges,
    pp.CommentCount AS TotalComments,
    pp.Score AS PostScore
FROM 
    UsersWithBadges up
JOIN 
    PopularPosts pp ON pp.PostId IN (SELECT PostId FROM Votes v WHERE v.UserId = up.UserId)
JOIN 
    TopTags tp ON tp.NormalizedTag = ANY(pp.Tags)
JOIN 
    Posts p ON pp.PostId = p.Id
ORDER BY 
    pp.Score DESC, TotalComments DESC
LIMIT 10;
