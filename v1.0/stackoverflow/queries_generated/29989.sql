WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.AnswerCount) AS TotalAnswers,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(rp.PostId) > 0
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
MostPopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        COUNT(*) DESC
    LIMIT 10
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        t.Tag AS PopularTag
    FROM 
        RankedPosts rp
    JOIN 
        MostPopularTags t ON t.Tag = ANY(string_to_array(rp.Tags, '>'))
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    pe.Title,
    pe.CreationDate,
    pe.ViewCount,
    pe.Score,
    pe.AnswerCount,
    pe.CommentCount,
    pe.PopularTag
FROM 
    PostEngagement pe
JOIN 
    TopUsers tu ON pe.PostId IN (
        SELECT PostId FROM RankedPosts WHERE OwnerUserId = tu.UserId
    )
ORDER BY 
    tu.Reputation DESC,
    pe.ViewCount DESC
LIMIT 50;
