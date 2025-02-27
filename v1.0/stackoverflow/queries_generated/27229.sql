WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
),
LargeBodyPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.Tags,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        r.OwnerDisplayName,
        r.OwnerReputation
    FROM 
        RankedPosts r
    WHERE 
        LEN(r.Body) > 1000 -- Only considering posts with body longer than 1000 characters
),
FrequentTagUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Tags) AS TagCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Tags) > 10 -- Users who have authored more than 10 questions
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        SUM(TagCount) AS TotalTags
    FROM 
        FrequentTagUsers
    GROUP BY 
        UserId, DisplayName
    ORDER BY 
        TotalTags DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY -- Get top 5 contributors
)
SELECT 
    lbp.PostId,
    lbp.Title,
    lbp.Body,
    lbp.CreationDate,
    lbp.Score,
    lbp.ViewCount,
    lbp.AnswerCount,
    lbp.OwnerDisplayName,
    lbp.OwnerReputation,
    tc.DisplayName AS TopContributor,
    tc.TotalTags
FROM 
    LargeBodyPosts lbp
JOIN 
    TopContributors tc ON lbp.OwnerDisplayName = tc.DisplayName
ORDER BY 
    lbp.Score DESC, lbp.ViewCount DESC; -- Order by score then view count
