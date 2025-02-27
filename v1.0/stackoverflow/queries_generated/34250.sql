WITH RecursiveVoteSummary AS (
    SELECT 
        v.PostId, 
        vt.Name AS VoteType, 
        COUNT(*) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) as VoteRank
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId, vt.Name
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        COALESCE(SUM(ph.PostHistoryTypeId = 10), 0) AS PostsClosed,
        COALESCE(SUM(ph.PostHistoryTypeId = 12), 0) AS PostsDeleted
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(vs.VoteCount, 0) AS TotalVotes,
        COALESCE(ua.PostsClosed, 0) AS ClosedCount,
        COALESCE(ua.PostsDeleted, 0) AS DeletedCount,
        COALESCE(tt.PostCount, 0) AS RelatedTagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, SUM(VoteCount) AS VoteCount FROM RecursiveVoteSummary GROUP BY PostId) vs ON p.Id = vs.PostId
    LEFT JOIN 
        RecentUserActivity ua ON p.OwnerUserId = ua.UserId
    LEFT JOIN 
        TopTags tt ON p.Tags LIKE '%' || tt.TagName || '%'
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.TotalVotes,
    pe.ClosedCount,
    pe.DeletedCount,
    pe.RelatedTagCount
FROM 
    PostEngagement pe
WHERE 
    pe.TotalVotes > 0
ORDER BY 
    pe.TotalVotes DESC
LIMIT 10;
