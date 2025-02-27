WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- We are only interested in questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Within the last year
),

TopTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Top 10 tags

),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    ut.UserId,
    ut.DisplayName,
    ut.Reputation,
    ut.QuestionCount,
    ut.TotalScore,
    tt.Tag,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserStats ut ON rp.OwnerUserId = ut.UserId
JOIN 
    TopTags tt ON tt.Tag = ANY(string_to_array(rp.Tags, '><'))
WHERE 
    rp.PostRank <= 5  -- Top 5 posts per user
ORDER BY 
    ut.Reputation DESC,  -- Sort by user reputation
    rp.Score DESC;  -- Then by post score
