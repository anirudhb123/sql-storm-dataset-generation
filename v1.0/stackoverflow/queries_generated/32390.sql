WITH RecursiveTagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.Id, t.TagName
),
UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        MAX(u.Reputation) OVER (PARTITION BY u.Id ORDER BY u.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MaxReputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        u.CreationDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate
),
TagPostLinkage AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostsWithExtendedInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(cr.CloseReasonCount, 0) AS CloseCount,
        p.CreationDate,
        COALESCE(rt.PostCount, 0) AS TagCount,
        up.UserId,
        up.ReputationRank,
        up.TotalBadges
    FROM 
        Posts p
    LEFT JOIN 
        CloseReasonCounts cr ON cr.PostId = p.Id
    LEFT JOIN 
        RecursiveTagCounts rt ON rt.TagId IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int) AS TagId)
    LEFT JOIN 
        UserReputationHistory up ON up.UserId = p.OwnerUserId
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CloseCount,
    TagCount,
    CreationDate,
    ReputationRank,
    TotalBadges
FROM 
    PostsWithExtendedInfo
WHERE 
    CloseCount > 0
ORDER BY 
    ViewCount DESC, TagCount DESC
LIMIT 50;
