WITH active_users AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.VoteCount IS NOT NULL THEN p.VoteCount ELSE 0 END) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        (SELECT 
            p.Id, 
            p.OwnerUserId, 
            p.PostTypeId, 
            COALESCE(v.VoteCount, 0) AS VoteCount
        FROM 
            Posts p
        LEFT JOIN 
            (SELECT 
                PostId,
                COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS VoteCount
            FROM 
                Votes 
            GROUP BY 
                PostId) v ON p.Id = v.PostId
        ) p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), popular_tags AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostsWithTag
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostsWithTag DESC
    LIMIT 5
), user_engagement AS (
    SELECT 
        a.UserId, 
        a.DisplayName, 
        a.Reputation,
        COALESCE(pt.PostCount, 0) AS TotalPosts,
        COALESCE(pt.QuestionsCount, 0) AS TotalQuestions,
        COALESCE(pt.AnswersCount, 0) AS TotalAnswers,
        COALESCE(pt.TotalVotes, 0) AS TotalVotes,
        ARRAY_AGG(DISTINCT pt.TagName) AS BestTags
    FROM 
        active_users a 
    LEFT JOIN 
        (SELECT 
            u.Id AS UserId, 
            u.DisplayName, 
            u.Reputation, 
            u.PostCount,
            QuestionsCount,
            AnswersCount,
            TotalVotes,
            UNNEST(ARRAY(SELECT TagName FROM popular_tags)) AS TagName
        FROM 
            active_users u 
        ) pt ON pt.UserId = a.UserId
    GROUP BY 
        a.UserId, a.DisplayName, a.Reputation
), detailed_stats AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName, 
        ue.Reputation, 
        ue.TotalPosts, 
        ue.TotalQuestions, 
        ue.TotalAnswers, 
        ue.TotalVotes,
        unnest(ue.BestTags) AS BestTag
    FROM 
        user_engagement ue
)

SELECT 
    ds.UserId, 
    ds.DisplayName, 
    ds.Reputation,
    ds.TotalPosts,
    ds.TotalQuestions,
    ds.TotalAnswers,
    ds.TotalVotes,
    ds.BestTag
FROM 
    detailed_stats ds
ORDER BY 
    ds.TotalVotes DESC, 
    ds.TotalPosts DESC;
