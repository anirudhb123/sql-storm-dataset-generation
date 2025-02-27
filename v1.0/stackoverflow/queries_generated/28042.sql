WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN pb.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN pb.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        COALESCE(SUM(v.VoteTypeId IN (2)), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId IN (3)), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts pb ON u.Id = pb.OwnerUserId
    LEFT JOIN 
        Votes v ON pb.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagNames
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    us.DisplayName,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpvotes,
    us.TotalDownvotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagNames
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.PostRank = 1 -- The latest question per user
ORDER BY 
    us.TotalUpvotes DESC, us.DisplayName;
