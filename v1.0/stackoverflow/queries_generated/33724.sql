WITH RecursiveTagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count
    FROM 
        Tags
    WHERE 
        Count > 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTagHierarchy rth ON rth.Id = t.Id
    WHERE 
        t.IsRequired = 1
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPerformance
),
ActiveTags AS (
    SELECT 
        TagName,
        SUM(Count) AS TotalCount
    FROM 
        Tags
    WHERE 
        Count > 0
    GROUP BY 
        TagName
)

SELECT 
    tu.DisplayName,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    COALESCE(at.TotalCount, 0) AS ActiveTagCount,
    (tu.TotalUpVotes - tu.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN tu.UpvoteRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopUsers tu
LEFT JOIN 
    ActiveTags at ON at.TagName = ANY(STRING_TO_ARRAY(
        (SELECT STRING_AGG(DISTINCT Tags ORDER BY Tags) 
         FROM (
             SELECT SUBSTRING(tags FROM 2 FOR LENGTH(tags)-2) AS Tags
             FROM Posts
             WHERE OwnerUserId = tu.UserId
             GROUP BY Tags
         ) AS derived_tags), ','))

ORDER BY 
    tu.TotalUpVotes DESC, 
    tu.DisplayName ASC;
