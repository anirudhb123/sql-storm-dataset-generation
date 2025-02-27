WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.UserId IS NOT NULL
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpvoteCount,
        DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
)
SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    ph.CreationDate,
    ph.Comment,
    ph.PostHistoryTypeId,
    CASE 
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
        WHEN ph.PostHistoryTypeId IN (24, 25) THEN 'Edited'
        ELSE 'Other'
    END AS ChangeType,
    CASE 
        WHEN u.Reputation IS NOT NULL THEN u.Reputation + (p.ViewCount / 1000.0)
        ELSE NULL
    END AS AdjustedReputation
FROM 
    TopUsers u
JOIN 
    RecursivePostHistory ph ON u.UserId = ph.UserId
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.RowNum = 1 -- only latest history entry
    AND p.Severity IS NOT NULL -- example filter for demonstration purposes
ORDER BY 
    u.Reputation DESC,
    ph.CreationDate DESC;

WITH TagAnalytics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT Posts.Id) DESC) AS TagRank
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
    HAVING 
        COUNT(DISTINCT Posts.Id) > 10
)
SELECT 
    ta.TagName,
    ta.PostCount,
    ta.TotalViews,
    ta.AverageScore
FROM 
    TagAnalytics ta
WHERE 
    ta.TagRank <= 5; -- Get top 5 tags
