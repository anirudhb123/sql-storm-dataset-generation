WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        CAST(0 AS INT) AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Reputation < ur.Reputation
    WHERE 
        ur.Level < 3
), RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
), PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        tag.TagName
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    up.DisplayName AS UserName,
    up.Reputation,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
    STRING_AGG(DISTINCT pt.TagName, ', ') AS TagsUsed,
    MAX(rp.Score) AS HighestScore
FROM 
    Users up
LEFT JOIN 
    Posts p ON up.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  -- BountyClose
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(p.Tags, '><'))
WHERE 
    up.Reputation IN (SELECT Reputation FROM UserReputation WHERE Level = 0)
GROUP BY 
    up.Id, up.DisplayName, up.Reputation
HAVING 
    COUNT(DISTINCT rp.Id) > 3
ORDER BY 
    up.Reputation DESC
LIMIT 10;
