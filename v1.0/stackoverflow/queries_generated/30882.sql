WITH RecursiveTags AS (
    SELECT
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired
    FROM
        Tags
    WHERE
        IsModeratorOnly = 1
    UNION ALL
    SELECT
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired
    FROM
        Tags t
    INNER JOIN RecursiveTags rt ON t.Count > rt.Count
),
UserReputation AS (
    SELECT 
        Id,
        Reputation,
        DisplayName,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY ph.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
VoteStatistics AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.NetVotes,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
    COUNT(DISTINCT rt.Id) AS ModeratorOnlyTagCount,
    SUM(vs.UpVotes) AS TotalUpVotes,
    SUM(vs.DownVotes) AS TotalDownVotes,
    STRING_AGG(DISTINCT rt.TagName, ', ') AS ModeratorOnlyTags
FROM 
    UserReputation u
LEFT JOIN 
    ClosedPosts cp ON cp.OwnerUserId = u.Id
LEFT JOIN 
    VoteStatistics vs ON vs.PostId IN (
        SELECT 
            PostId 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = u.Id
    )
LEFT JOIN 
    RecursiveTags rt ON u.Id IN (
        SELECT 
            UserId 
        FROM 
            Badges 
        WHERE 
            UserId = u.Id 
            AND Class = 1 -- Gold badges
    )
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.NetVotes
HAVING 
    COUNT(DISTINCT cp.PostId) > 0
ORDER BY 
    u.Reputation DESC, ClosedPostCount DESC;
