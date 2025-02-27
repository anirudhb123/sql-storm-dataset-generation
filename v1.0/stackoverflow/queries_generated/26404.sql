WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId -- Joining answers
    LEFT JOIN 
        Comments c ON p.Id = c.PostId -- Joining comments
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, U.DisplayName
),

RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS ActivityDate,
        pt.Name AS PostHistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' -- Last 30 days
),

AnsweredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        ra.UserDisplayName AS AnswererName,
        ra.CreationDate AS AnswerDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts a ON rp.PostId = a.ParentId
    LEFT JOIN 
        Users ra ON a.OwnerUserId = ra.Id
    WHERE 
        rp.AnswerCount > 0
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(a.AnswererName, 'No answers yet') AS MostRecentAnswerer,
    COUNT(DISTINCT ra.UserDisplayName) AS UniqueAnswerers,
    COUNT(DISTINCT r.ActivityDate) AS RecentActivities,
    STRING_AGG(DISTINCT r.Comment, '; ') AS RecentComments
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity r ON rp.PostId = r.PostId
LEFT JOIN 
    AnsweredPosts a ON rp.PostId = a.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.AnswerCount, rp.CommentCount, a.AnswererName
ORDER BY 
    rp.AnswerCount DESC, rp.CreationDate DESC
LIMIT 50; -- Top 50 questions sorted by answer count
