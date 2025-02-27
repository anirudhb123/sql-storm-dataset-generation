WITH RankedVotes AS (
    SELECT 
        p.Id AS PostId,
        U.Id AS UserId,
        V.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY V.CreationDate DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Votes V ON p.Id = V.PostId
    JOIN 
        Users U ON V.UserId = U.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        RankedVotes
    WHERE 
        VoteRank = 1 -- only consider the latest vote per post
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        COALESCE(CAST(NULLIF(ph.UserId, -1) AS INT), -1) AS CloserUserId,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(c.CloserUserId, -1) AS ClosedByUserId,
        COALESCE(c.ClosedDate, CAST(NULL AS TIMESTAMP)) AS ClosedDate,
        ps.UpVotes,
        ps.DownVotes,
        ps.TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPosts c ON p.Id = c.Id
    LEFT JOIN 
        PostVoteSummary ps ON p.Id = ps.PostId
)
SELECT 
    d.PostId,
    d.Title,
    d.ViewCount,
    d.ClosedByUserId,
    d.ClosedDate,
    d.UpVotes,
    d.DownVotes,
    CASE 
        WHEN d.ClosedDate IS NOT NULL THEN 'Post is Closed'
        ELSE 'Post is Open'
    END AS PostStatus,
    (CASE 
        WHEN d.TotalVotes IS NULL OR d.TotalVotes = 0 THEN 'No Votes Yet'
        ELSE CONCAT('Votes: ', d.UpVotes - d.DownVotes)
     END) AS VoteSummary,
    (SELECT 
        STRING_AGG(tag.TagName, ', ') 
     FROM 
        Tags tag 
     JOIN 
        LATERAL(SELECT unnest(string_to_array(p.Tags, '><')) AS t) AS tag_names ON tag.TagName = tag_names.t
     WHERE 
        p.Id = d.PostId) AS AssociatedTags
FROM 
    PostDetails d
WHERE 
    d.ViewCount > 100 -- arbitrary condition to filter popular posts
ORDER BY 
    d.ViewCount DESC NULLS LAST
LIMIT 50;
