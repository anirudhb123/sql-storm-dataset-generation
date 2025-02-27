WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
TopVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.UserId) AS TotalVoters
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    ra.CommentCount,
    COALESCE(tv.UpVotes, 0) AS UpVotes,
    COALESCE(tv.DownVotes, 0) AS DownVotes,
    rp.Score,
    rp.ViewCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Available'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus,
    (SELECT 
        STRING_AGG(DISTINCT tt.TagName, ', ') 
     FROM 
        Tags tt, 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_name
     WHERE 
        p.Id = tt.Id) AS Tags,
    rp.PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.Id = ra.PostId
LEFT JOIN 
    TopVotedPosts tv ON rp.Id = tv.Id
WHERE 
    rp.PostRank <= 5 -- Only the top 5 recent posts per user
ORDER BY 
    rp.CreationDate DESC;
