-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT
        u.Id AS UserID,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)

SELECT
    UserID,
    DisplayName,
    PostCount,
    Questions,
    Answers,
    TotalScore,
    TotalViews,
    UpVotes,
    DownVotes,
    Reputation,
    CreationDate,
    LastAccessDate
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserID = u.Id
ORDER BY 
    PostCount DESC, TotalScore DESC;
