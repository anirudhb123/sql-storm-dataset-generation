
WITH RecentUsers AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        CreationDate,
        LastAccessDate
    FROM 
        Users
    WHERE 
        CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(MONTH, 6, 0)
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
    ORDER BY 
        TotalViews DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(b.Class) AS AverageBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName AS User,
    u.Reputation,
    u.Views,
    u.UpVotes,
    u.DownVotes,
    u.CreationDate,
    u.LastAccessDate,
    pt.TagName AS PopularTag,
    ut.CommentCount,
    ut.VoteCount,
    ut.AverageBadgeClass
FROM 
    RecentUsers u
JOIN 
    UserInteractions ut ON u.UserId = ut.UserId
JOIN 
    PopularTags pt ON pt.PostCount > 1
ORDER BY 
    u.LastAccessDate DESC,
    ut.VoteCount DESC;
