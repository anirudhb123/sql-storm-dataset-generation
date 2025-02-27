WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount, 
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpvoteCount,
        DownvoteCount,
        PostCount,
        AvgReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, UpvoteCount DESC) AS UserRank
    FROM 
        UserStats
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS Popularity,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))/3600) AS AvgAgeInHours
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
PostsByTag AS (
    SELECT 
        p.Title, 
        p.CreationDate,
        p.Score,
        p.Id AS PostId,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS TagPostRank
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        COALESCE(CAST(ph.Comment AS INT), 0) AS CloseReasonId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalResults AS (
    SELECT 
        pu.DisplayName,
        pt.TagName,
        pp.Title AS PostTitle,
        pp.Score,
        pp.CreationDate AS PostCreationDate,
        CASE 
            WHEN cp.CloseReasonId IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        TopUsers pu
    JOIN 
        PostsByTag pp ON pu.UserId = pp.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON pp.PostId = cp.PostId
    JOIN 
        PopularTags pt ON pp.TagName = pt.TagName
    WHERE 
        pu.UserRank <= 10 
        AND pp.TagPostRank <= 5
)
SELECT 
    DisplayName, 
    TagName, 
    PostTitle, 
    Score,
    PostCreationDate, 
    PostStatus
FROM 
    FinalResults
ORDER BY 
    TagName, PostScore DESC;
