-- Performance benchmarking query to analyze posts, their types, associated users, and vote counts
WITH PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ViewCount,
        p.Score,
        COALESCE(vote_counts.UpVotes, 0) AS UpVotes,
        COALESCE(vote_counts.DownVotes, 0) AS DownVotes,
        COALESCE(vote_counts.TotalVotes, 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS vote_counts ON p.Id = vote_counts.PostId
),
PostUserDetails AS (
    SELECT 
        pvc.PostId,
        pvc.Title,
        pvc.ViewCount,
        pvc.Score,
        pvc.UpVotes,
        pvc.DownVotes,
        pvc.TotalVotes,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        u.Location AS OwnerLocation,
        u.CreationDate AS OwnerCreationDate
    FROM 
        PostVoteCounts pvc
    LEFT JOIN 
        Users u ON pvc.OwnerUserId = u.Id
)
SELECT
    pud.PostId,
    pud.Title,
    pud.ViewCount,
    pud.Score,
    pud.UpVotes,
    pud.DownVotes,
    pud.TotalVotes,
    pud.OwnerDisplayName,
    pud.OwnerReputation,
    pud.OwnerLocation,
    pud.OwnerCreationDate
FROM 
    PostUserDetails pud
WHERE 
    pud.TotalVotes > 0
ORDER BY 
    pud.Score DESC, pud.TotalVotes DESC
LIMIT 100;
