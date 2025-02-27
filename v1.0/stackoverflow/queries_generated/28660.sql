WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        (SELECT COUNT(*) FROM Comments co WHERE co.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON (t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '<>'))))
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),
UserPostHistory AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TotalEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10) THEN 1 ELSE 0 END) AS TotalClosedPosts
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        ph.UserId
),
AggregateData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        uph.TotalPosts,
        uph.EditHistoryCount,
        uph.TotalEdits,
        uph.TotalClosedPosts,
        rp.TotalComments,
        rp.Tags,
        rp.Title,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        UserPostHistory uph ON u.Id = uph.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    EditHistoryCount,
    TotalEdits,
    TotalClosedPosts,
    Title,
    Tags,
    UpvoteCount,
    DownvoteCount,
    TotalComments
FROM 
    AggregateData
WHERE 
    Tags IS NOT NULL
    AND TotalPosts > 5
ORDER BY 
    TotalPosts DESC, UpvoteCount DESC;
