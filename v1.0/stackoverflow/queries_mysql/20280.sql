
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        @row_number := IF(@prev_post_typeid = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_typeid := p.PostTypeId,
        COALESCE(NULLIF(p.Body, ''), 'No content provided') AS PostBody
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_post_typeid := NULL) AS vars
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 2 YEAR)
    ORDER BY 
        p.PostTypeId, p.Score DESC
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
VotesWithUserNames AS (
    SELECT 
        v.PostId,
        u.DisplayName AS VoterName,
        v.CreationDate,
        v.VoteTypeId,
        (CASE 
            WHEN v.VoteTypeId = 2 THEN 'Upvote'
            WHEN v.VoteTypeId = 3 THEN 'Downvote'
            ELSE 'Other'
        END) AS VoteType
    FROM 
        Votes v
    LEFT JOIN 
        Users u ON v.UserId = u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        COALESCE(c.Name, 'No Reason') AS CloseReasonName
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS UNSIGNED) = c.Id AND ph.PostHistoryTypeId = 10
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score,
    rp.PostBody,
    SUM(u.UpVotesCount) AS TotalUpVotes,
    SUM(u.DownVotesCount) AS TotalDownVotes,
    COUNT(vwu.VoterName) AS TotalVoters,
    GROUP_CONCAT(DISTINCT vwu.VoterName) AS VoterNames,
    GROUP_CONCAT(DISTINCT CASE WHEN phd.PostHistoryTypeId = 10 
                              THEN phd.CloseReasonName 
                              ELSE NULL END) AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteSummary u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    VotesWithUserNames vwu ON rp.PostID = vwu.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostID = phd.PostId
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostID, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.PostBody
HAVING 
    COUNT(DISTINCT vwu.VoterName) > 0 OR COUNT(DISTINCT phd.PostId) = 0
ORDER BY 
    rp.Score DESC;
