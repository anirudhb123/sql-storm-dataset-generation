WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- only count upvotes and downvotes
    LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    WHERE p.PostTypeId = 1  -- Only Questions
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.OwnerUserId, u.DisplayName
), 

StringMetrics AS (
    SELECT 
        PostId,
        LENGTH(Title) AS TitleLength,
        LENGTH(Body) AS BodyLength,
        LENGTH(Tags) AS TagsLength,
        CreationDate,
        OwnerDisplayName,
        ViewCount,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank,
        RANK() OVER (ORDER BY VoteCount DESC) AS VoteRank
    FROM RankedPosts
)

SELECT 
    PostId,
    Title,
    TitleLength,
    BodyLength,
    TagsLength,
    CreationDate,
    OwnerDisplayName,
    ViewCount,
    CommentCount,
    VoteCount,
    ViewRank,
    CommentRank,
    VoteRank,
    CASE 
        WHEN ViewRank <= 10 THEN 'Top 10 Viewed'
        WHEN CommentRank <= 10 THEN 'Top 10 Commented'
        WHEN VoteRank <= 10 THEN 'Top 10 Voted'
        ELSE 'Standard Post'
    END AS Category
FROM StringMetrics
ORDER BY ViewCount DESC, CommentCount DESC, VoteCount DESC
LIMIT 100;
