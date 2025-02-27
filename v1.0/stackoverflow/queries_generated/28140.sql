WITH PostTagCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p 
    INNER JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (2, 1) -- Answered or asked questions
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.Comment, 'No comments') AS RecentComment,
        RANK() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 OR p.PostTypeId = 2 -- Questions or Answers
)
SELECT 
    p.PostId,
    p.Title,
    pt.TagCount,
    pt.Tags,
    pu.DisplayName AS ActiveUser,
    pu.TotalViews,
    ra.RecentComment
FROM 
    PostTagCount pt
JOIN 
    RecentPostActivity ra ON pt.PostId = ra.PostId
JOIN 
    PopularUsers pu ON pu.QuestionsAnswered > 5 AND pu.UserId = ra.PostId
WHERE 
    ra.CommentRank = 1
ORDER BY 
    pt.TagCount DESC, pu.TotalViews DESC;
