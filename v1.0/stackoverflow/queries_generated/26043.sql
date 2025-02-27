WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 -- Get top 5 recent questions per user
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT rp.PostId) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.QuestionCount,
    AVG(fp.ViewCount) AS AverageViewCount,
    AVG(fp.AnswerCount) AS AverageAnswerCount,
    STRING_AGG(fp.Tags, '; ') AS AssociatedTags
FROM 
    UserReputation ur
LEFT JOIN 
    FilteredPosts fp ON ur.UserId = fp.OwnerUserId
GROUP BY 
    ur.DisplayName, ur.Reputation, ur.QuestionCount
ORDER BY 
    ur.Reputation DESC;
