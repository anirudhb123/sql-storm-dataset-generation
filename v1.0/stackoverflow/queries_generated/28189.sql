WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Assuming 2 is UpMod
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Assuming 3 is DownMod
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(UP.UpVotes, 0) - COALESCE(DOWN.DownVotes, 0)) AS AvgVoteDifference,
        COUNT(DISTINCT b.Id) AS BadgesReceived
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) UP ON p.PostId = UP.PostId
    GROUP BY 
        u.Id
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        TotalViews,
        AvgVoteDifference,
        BadgesReceived,
        ROW_NUMBER() OVER (ORDER BY QuestionsAsked DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    QuestionsAsked,
    TotalViews,
    AvgVoteDifference,
    BadgesReceived
FROM 
    MostActiveUsers
WHERE 
    UserRank <= 10 -- Top 10 users by questions asked
ORDER BY 
    QuestionsAsked DESC;
