
WITH RankedPostTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY t.Count DESC) AS TagRank
    FROM 
        Posts p
    CROSS APPLY (
        SELECT tag.value AS tag
        FROM STRING_SPLIT(REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', ' '), '><', ' '), ' ', NULL) AS tag
    ) AS tag
    JOIN 
        Tags t ON t.TagName = tag.tag
    WHERE 
        p.PostTypeId = 1 
),
TopTags AS (
    SELECT 
        PostId,
        STRING_AGG(TagName, ', ') WITHIN GROUP (ORDER BY TagRank) AS TagsList
    FROM 
        RankedPostTags
    WHERE 
        TagRank <= 3 
    GROUP BY 
        PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.AcceptedAnswers,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    t.TagsList
FROM 
    UserPostStats ups
JOIN 
    Posts p ON p.OwnerUserId = ups.UserId
JOIN 
    TopTags t ON t.PostId = p.Id
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalPosts DESC, p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
