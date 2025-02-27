WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        tag.Id AS TagId,
        tag.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON tag.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int)
    GROUP BY 
        tag.Id, tag.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    ORDER BY 
        p.Score DESC
),
UserBenchmark AS (
    SELECT 
        ur.DisplayName,
        ur.Reputation,
        ur.TotalPosts,
        ur.TotalQuestions,
        ur.TotalAnswers,
        ur.TotalScore,
        ur.TotalUpVotes,
        ur.TotalDownVotes,
        ARRAY_AGG(DISTINCT tt.TagName) AS TopTags
    FROM 
        UserReputation ur
    JOIN 
        Posts p ON ur.UserId = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    JOIN 
        TopTags tt ON tt.TagName = ANY(TopTags)
    GROUP BY 
        ur.UserId
)
SELECT 
    ub.DisplayName,
    ub.Reputation,
    ub.TotalPosts,
    ub.TotalQuestions,
    ub.TotalAnswers,
    ub.TotalScore,
    ub.TotalUpVotes,
    ub.TotalDownVotes,
    STRING_AGG(DISTINCT ub.TopTags, ', ') AS TopTags
FROM 
    UserBenchmark ub
GROUP BY 
    ub.DisplayName, ub.Reputation, ub.TotalPosts, ub.TotalQuestions, ub.TotalAnswers, ub.TotalScore, ub.TotalUpVotes, ub.TotalDownVotes
ORDER BY 
    ub.TotalScore DESC, ub.Reputation DESC
LIMIT 10;
