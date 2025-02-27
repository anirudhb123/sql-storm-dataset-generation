WITH RankedTags AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        ARRAY_AGG(DISTINCT u.DisplayName) AS TopContributors,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        t.TagName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRanking,
        ARRAY_AGG(DISTINCT c.Text) AS Comments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.Score
)
SELECT 
    rt.TagName,
    rt.PostCount,
    rt.TotalUpvotes,
    rt.TotalDownvotes,
    rt.TopContributors,
    pp.PostId,
    pp.Title AS PostTitle,
    pp.ViewCount AS PostViewCount,
    pp.AnswerCount AS PostAnswerCount,
    pp.Score AS PostScore,
    pp.Comments AS PostComments
FROM 
    RankedTags rt
JOIN 
    PopularPosts pp ON pp.PostId IN (
        SELECT p.Id
        FROM Posts p
        WHERE p.Tags LIKE '%' || rt.TagName || '%'
        LIMIT 5
    )
WHERE 
    rt.TagRank <= 10 -- Top 10 tags
ORDER BY 
    rt.TagRank, pp.ViewCount DESC;
