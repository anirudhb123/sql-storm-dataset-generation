WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PopularTags AS (
    SELECT 
        t.TagName,
        t.Count AS TagCount,
        DENSE_RANK() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM 
        Tags t
    WHERE 
        t.Count > 0
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    pt.TagName,
    pt.TagCount,
    ap.Title AS RecentQuestionTitle,
    ap.CreationDate AS QuestionDate,
    ap.Score AS QuestionScore,
    ap.CommentCount
FROM 
    RankedUsers ru
JOIN 
    ActivePosts ap ON ru.UserId = ap.OwnerUserId
JOIN 
    PostLinks pl ON ap.PostId = pl.PostId
JOIN 
    Tags pt ON pt.Id = pl.RelatedPostId -- Assuming RelatedPostId points to tag ids in Posts
WHERE 
    ru.ReputationRank <= 10 
    AND ap.UserPostRank = 1
ORDER BY 
    ru.Reputation DESC, pt.TagCount DESC;
