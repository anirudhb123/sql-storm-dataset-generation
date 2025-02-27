WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        AverageReputation,
        RANK() OVER (ORDER BY PostCount DESC, AverageReputation DESC) AS UserRank
    FROM 
        UserPostStats
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
)
SELECT 
    ru.DisplayName,
    ru.PostCount,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.TotalBounty,
    ru.AverageReputation,
    pt.TagName,
    pt.TagUsage,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVoteCount,
    COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount
FROM 
    RankedUsers ru
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(p.Tags, ',')))
WHERE 
    ru.UserRank <= 10 -- Just get the top 10
GROUP BY 
    ru.UserId, ru.DisplayName, pt.TagName, pt.TagUsage
ORDER BY 
    ru.UserRank;
