WITH tag_stats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
user_activity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS OwnPostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
recent_activity AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        DENSE_RANK() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.ClosedCount,
    ua.UserId,
    ua.TotalPosts,
    ua.OwnPostCount,
    ua.UpVoteCount,
    ua.DownVoteCount,
    ra.ActivityRank
FROM 
    tag_stats ts
JOIN 
    user_activity ua ON ua.TotalPosts > 0
LEFT JOIN 
    recent_activity ra ON ra.UserId = ua.UserId
WHERE 
    ts.PostCount > 50
ORDER BY 
    ts.PostCount DESC, 
    ua.TotalPosts DESC, 
    ra.ActivityRank;
