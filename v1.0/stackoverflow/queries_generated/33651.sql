WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        CreationDate,
        0 AS Level,
        OwnerUserId
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start with root posts (questions)

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        p.CreationDate,
        Level + 1,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),

PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
),

FinalPostReport AS (
    SELECT 
        r.Id AS PostId, 
        r.Title, 
        r.CreationDate,
        r.Level,
        v.UpVoteCount,
        v.DownVoteCount,
        v.TotalVotes,
        v.BadgeCount,
        (v.UpVoteCount - v.DownVoteCount) AS NetVotes,
        DATE_PART('year', AGE(r.CreationDate)) AS YearsOld
    FROM 
        RecursivePostHierarchy r
    JOIN 
        PostVoteDetails v ON r.Id = v.PostId
)

SELECT 
    PostId, 
    Title, 
    CreationDate, 
    Level,
    UpVoteCount,
    DownVoteCount,
    TotalVotes,
    BadgeCount,
    NetVotes,
    YearsOld,
    CASE 
        WHEN NetVotes < 0 THEN 'Negative'
        WHEN NetVotes = 0 THEN 'Neutral'
        ELSE 'Positive'
    END AS VoteStatus
FROM 
    FinalPostReport
WHERE 
    YearsOld > 1  -- Filter for posts older than 1 year
ORDER BY 
    Level, NetVotes DESC, CreationDate DESC;
