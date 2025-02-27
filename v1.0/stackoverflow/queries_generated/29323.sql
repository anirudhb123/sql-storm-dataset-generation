WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- questions and answers
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id -- Assuming Comment holds the CloseReasonId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) -- Parsing tags
    GROUP BY 
        tag.TagName
    HAVING 
        COUNT(p.Id) > 10 -- More than 10 posts associated
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    cp.ClosedDate,
    cp.CloseReason,
    tt.TagName,
    ua.DisplayName AS ActiveUser,
    ua.UpVotesCount,
    ua.DownVotesCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PopularTags tt ON tt.PostCount > 0
LEFT JOIN 
    UserActivity ua ON ua.UserId = rp.OwnerDisplayName
WHERE 
    rp.RankScore <= 5 -- Select only top 5 posts per type
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
