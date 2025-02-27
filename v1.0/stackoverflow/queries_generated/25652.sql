WITH UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        RANK() OVER (ORDER BY up.TotalPosts DESC) AS PostRank
    FROM 
        Users u
    JOIN 
        UserPosts up ON u.Id = up.OwnerUserId
    WHERE 
        u.Reputation > 1000
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        p.Id
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    pt.TagName,
    (pi.CommentCount + pi.UpVoteCount - pi.DownVoteCount) AS EngagementScore
FROM 
    TopUsers tu
JOIN 
    PostInteraction pi ON pi.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.Id)
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) FROM Posts p WHERE p.OwnerUserId = tu.Id)
WHERE 
    tu.PostRank <= 10
ORDER BY 
    EngagementScore DESC;
