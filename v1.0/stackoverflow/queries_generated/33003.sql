WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted
), 

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCENCE(v.VoteTypeId = 2, 0, 1)) AS UpVotesCount,  -- Count upvotes
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotesCount  -- Count downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(p.ClosedDate, '1900-01-01') AS ClosedDate,  -- Manage NULL for ClosedDate
        MAX(CASE WHEN u.UserId IS NOT NULL THEN u.DisplayName ELSE 'Community' END) AS OwnerName  -- Manage potential NULL user
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHistory rph ON p.Id = rph.PostId
    LEFT JOIN 
        UserActivity u ON p.OwnerUserId = u.UserId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.ClosedDate
),

TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.AnswerCount,
        ps.ClosedDate,
        ps.OwnerName,
        ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC, ps.AnswerCount DESC) AS PostRank
    FROM 
        PostStats ps
    WHERE 
        ps.ViewCount > 0  -- Filter posts with views
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.ClosedDate,
    tp.OwnerName,
    CASE 
        WHEN tp.ClosedDate > '1900-01-01' THEN 'Closed'
        ELSE 'Open'
    END AS Status,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT STRING_AGG(DISTINCT tt.TagName, ', ') 
      FROM Tags tt 
      INNER JOIN LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tt.TagName = tag 
      WHERE p.Id = tp.PostId) AS TagsUsed
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10  -- Limit to top 10 posts
ORDER BY 
    tp.PostRank;
