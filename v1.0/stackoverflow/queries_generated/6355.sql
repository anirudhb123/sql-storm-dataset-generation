WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN AnswerCount > 5 THEN 'High Activity'
            WHEN AnswerCount BETWEEN 1 AND 5 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        RankedPosts
    WHERE 
        rn = 1 -- Get the latest question of each user
), Summary AS (
    SELECT 
        ActivityLevel,
        COUNT(*) AS TotalPosts,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes
    FROM 
        FilteredPosts
    GROUP BY 
        ActivityLevel
)
SELECT 
    s.ActivityLevel,
    s.TotalPosts,
    s.AvgUpVotes,
    s.AvgDownVotes,
    p2.Title AS SamplePostTitle
FROM 
    Summary s
LEFT JOIN 
    FilteredPosts p2 ON p2.ActivityLevel = s.ActivityLevel
ORDER BY 
    s.TotalPosts DESC, s.ActivityLevel;
