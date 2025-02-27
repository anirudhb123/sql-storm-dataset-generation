WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        UpVotes,
        DownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserVoteStats 
    JOIN 
        Users ON UserVoteStats.UserId = Users.Id
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    t.TagName,
    t.PostCount
FROM 
    TopUsers u
JOIN 
    PopularTags t ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE 
            p.OwnerUserId = u.UserId AND 
            p.Tags LIKE '%' || t.TagName || '%'
    )
WHERE 
    u.ReputationRank <= 10
ORDER BY 
    u.Reputation DESC, t.PostCount DESC;
