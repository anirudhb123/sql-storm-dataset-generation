WITH PopularTags AS (
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags 
    JOIN 
        Posts ON Tags.Id = Posts.Id 
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Tags.TagName 
    HAVING 
        COUNT(Posts.Id) > 5
),
UserReputation AS (
    SELECT 
        Users.Id, 
        Users.DisplayName, 
        SUM(Votes.VoteTypeId = 2) AS TotalUpVotes,
        SUM(Votes.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users 
    JOIN 
        Votes ON Users.Id = Votes.UserId 
    GROUP BY 
        Users.Id, Users.DisplayName
),
RecentPostHistory AS (
    SELECT 
        PostHistory.PostId,
        PostHistory.CreationDate,
        PostHistory.Comment,
        PostHistory.UserId,
        Users.DisplayName
    FROM 
        PostHistory 
    JOIN 
        Users ON PostHistory.UserId = Users.Id
    WHERE 
        PostHistory.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    ut.DisplayName AS UserName,
    ut.TotalUpVotes, 
    ut.TotalDownVotes,
    pt.TagName,
    p.Title AS PostTitle,
    MAX(rph.CreationDate) AS LastEditDate
FROM 
    UserReputation ut
JOIN 
    PopularTags pt ON ut.TotalUpVotes > 10
JOIN 
    Posts p ON p.OwnerUserId = ut.Id
LEFT JOIN 
    RecentPostHistory rph ON p.Id = rph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '6 months'
GROUP BY 
    ut.DisplayName, pt.TagName, p.Title
ORDER BY 
    ut.TotalUpVotes DESC, pt.TagName ASC;
