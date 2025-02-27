WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    GROUP BY 
        t.TagName
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
), 
UserPostDetails AS (
    SELECT 
        u.DisplayName,
        u.CreationDate AS UserCreated,
        ur.AvgReputation,
        ur.TotalBadges,
        pa.PostStatus,
        pa.Score,
        pa.CommentCount,
        pa.RevisionCount,
        pa.VoteCount
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    JOIN 
        PostActivity pa ON u.Id = pa.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.UserCreated,
    up.AvgReputation,
    up.TotalBadges,
    STRING_AGG(DISTINCT tc.TagName, ', ') AS AssociatedTags,
    COUNT(DISTINCT pa.PostId) AS TotalPosts,
    AVG(pa.Score) AS AvgPostScore,
    SUM(CASE WHEN pa.PostStatus = 'Closed' THEN 1 ELSE 0 END) AS ClosedPostCount
FROM 
    UserPostDetails up
LEFT JOIN 
    PostActivity pa ON up.UserId = pa.OwnerUserId
LEFT JOIN 
    TagCounts tc ON pa.PostId IN (SELECT id FROM Posts WHERE Tags @> ('<' || tc.TagName || '>')::varchar)
GROUP BY 
    up.DisplayName, up.UserCreated, up.AvgReputation, up.TotalBadges
ORDER BY 
    AvgPostScore DESC NULLS LAST;
